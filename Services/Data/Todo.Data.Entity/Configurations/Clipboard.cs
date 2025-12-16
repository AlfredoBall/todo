using System.Reflection.Emit;
using System.Reflection.Metadata;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Todo.Data.Entity.Configuration;

internal class ClipboardConfiguration : IEntityTypeConfiguration<Clipboard>
{
    private const string TableName = "Clipboard";
    public void Configure(EntityTypeBuilder<Clipboard> builder)
    {
        builder
            .ToTable(TableName);

        builder.Property<int>(p => p.ID).HasColumnName("ID");

        builder.Property(p => p.ID).ValueGeneratedOnAdd();

        builder.HasIndex(c => c.Name).IsUnique();

        builder.Property(p => p.Name)
            .IsRequired()
            .HasMaxLength(40);

        builder.HasMany(p => p.Items)
            .WithOne()
            .HasForeignKey("ClipboardID")
            .OnDelete(DeleteBehavior.Cascade);
    }
}